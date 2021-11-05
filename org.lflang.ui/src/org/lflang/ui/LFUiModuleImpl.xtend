/*
 * generated by Xtext 2.17.0
 */
package org.lflang.ui

import java.util.LinkedList
import java.util.List
import org.eclipse.jface.text.BadLocationException
import org.eclipse.jface.text.DocumentCommand
import org.eclipse.jface.text.IDocument
import org.eclipse.jface.text.IRegion
import org.eclipse.jface.text.TextUtilities
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import org.eclipse.xtext.ui.editor.autoedit.AbstractEditStrategyProvider.IEditStrategyAcceptor
import org.eclipse.xtext.ui.editor.autoedit.AbstractTerminalsEditStrategy
import org.eclipse.xtext.ui.editor.autoedit.CommandInfo
import org.eclipse.xtext.ui.editor.autoedit.DefaultAutoEditStrategyProvider
import org.eclipse.xtext.ui.editor.autoedit.MultiLineTerminalsEditStrategy
import org.eclipse.xtext.ui.editor.autoedit.SingleLineTerminalsStrategy
import com.google.inject.Provider
import org.eclipse.xtext.resource.containers.IAllContainersState

import org.eclipse.ui.console.MessageConsole
import org.eclipse.ui.console.ConsolePlugin
import java.io.PrintStream

/**
 * Use this class to register components to be used within the Eclipse IDE.
 * 
 * This subclass provides an astonishingly opaque and complex override of
 * the default editor behavior to properly handle the code body delimiters
 * {= ... =} of Lingua Franca.  It is disheartening how difficult this was
 * to accomplish.  The design of xtext does not seem to lend itself to
 * subclassing, and the code has no comments in it at all.
 */
@FinalFieldsConstructor
class LFUiModuleImpl extends AbstractLFUiModule {
    
    static var consoleInitialized = false
    
    // Instead of classpath, use Properties -> Project Reference
    override Provider<IAllContainersState> provideIAllContainersState() {
       return org.eclipse.xtext.ui.shared.Access.getJavaProjectsState();
    }
    
    
    def Class<? extends DefaultAutoEditStrategyProvider> bindAutoEditStrategy() {
        return LinguaFrancaAutoEdit
    }
    
    static class LinguaFrancaAutoEdit extends DefaultAutoEditStrategyProvider {
        // After a huge amount of experimentation with completely undocumented
        // xtext code, the following seems to provide auto completion for codeblock
        // delimiters for Lingua Franca.
        
        /**
         * Handle combinations of nested braces.
         * The following from the base class completely messes up with codeblocks.
         * So we replace it below. Unfortunately, the base class CompoundMultiLineTerminalsEditStrategy
         * is not written in a way that can be overridden, so we have to completely
         * reimplement it.
         */
        override void configureCompoundBracesBlocks(IEditStrategyAcceptor acceptor) {
            // Base class has the following, which uses a factory:
            // acceptor.accept(compoundMultiLineTerminals.newInstanceFor("{", "}").and("[", "]").and("(", ")"), IDocument.DEFAULT_CONTENT_TYPE);
            // We can't use that here because the factory creates instances of
            // CompoundLFMultiLineTerminalsEditStrategy and we need CompoundMultiLineTerminalsEditStrategy.
            // It is not clear to me why only one of the following is needed.
            // It doesn't seem to matter which one.
            // acceptor.accept(new CompoundLFMultiLineTerminalsEditStrategy("{", "}"), IDocument.DEFAULT_CONTENT_TYPE);
            // acceptor.accept(new CompoundLFMultiLineTerminalsEditStrategy("(", ")"), IDocument.DEFAULT_CONTENT_TYPE);
            // acceptor.accept(new CompoundLFMultiLineTerminalsEditStrategy("[", "]"), IDocument.DEFAULT_CONTENT_TYPE);
            acceptor.accept(new CompoundLFMultiLineTerminalsEditStrategy("{=", "=}"), IDocument.DEFAULT_CONTENT_TYPE);
        }
        
        /**
         * For the given document, return the indentation of the line at
         * the specified offset. If the indentation is accomplished with
         * tabs, count each tab as four spaces.
         * @param document The document.
         * @param offset The offset.
         */
        static def indentationAt(IDocument document, int offset) {
            val lineNumber = document.getLineOfOffset(offset) // Line number.
            val lineStart = document.getLineOffset(lineNumber) // Offset of start of line.
            val lineLength = document.getLineLength(lineNumber) // Length of the line.
            var line = document.get(lineStart, lineLength)
            line = line.replaceAll("\t", "    ")
            // Replace all tabs with four spaces.
            return line.indexOf(line.trim())
        }
                
        /**
         * When encountering {= append =}.
         */
        protected def configureCodeBlock(IEditStrategyAcceptor acceptor) {
            acceptor.accept(new SingleLineTerminalsStrategy("{=", "=}", SingleLineTerminalsStrategy.DEFAULT) {
                    override void handleInsertLeftTerminal(IDocument document, DocumentCommand command)
                            throws BadLocationException {
                        if (command.text.length() > 0 && appliedText(document, command).endsWith(getLeftTerminal())
                                && isInsertClosingTerminal(document, command.offset + command.length)) {
                            val documentContent = getDocumentContent(document, command);
                            val opening = count(getLeftTerminal(), documentContent);
                            val closing = count(getRightTerminal(), documentContent);
                            val occurences = opening + closing;
                            if (occurences % 2 == 0) {
                                command.caretOffset = command.offset + command.text.length();
                                // Do not insert the right delimitter '=}' because there is already
                                // a '}' from the previous auto complete when the '{' was typed.
                                command.text = command.text + '=';
                                command.shiftsCaret = false;
                            }
                        }
                    }
    
                    override boolean isInsertClosingTerminal(IDocument doc, int offset) {
                        if (doc.getLength() <= offset) return true;
                        if (offset == 0) return false;
                        // xtend fails horribly with char literals, so we have to
                        // convert this to a string.
                        val charAtOffset = Character.toString(doc.getChar(offset));
                        val charBeforeOffset = Character.toString(doc.getChar(offset - 1));
                        val result = ((charAtOffset == '}') && charBeforeOffset == '{')
                        return result
                    }
                },
                IDocument.DEFAULT_CONTENT_TYPE
            );
        }
        
        /**
         * When hitting Return with a code block, move the =} to a newline properly indented.
         */
        protected def configureMultilineCodeBlock(IEditStrategyAcceptor acceptor) {
            acceptor.accept(new LFMultiLineTerminalsEditStrategy("(", ")", true), IDocument.DEFAULT_CONTENT_TYPE)
            acceptor.accept(new LFMultiLineTerminalsEditStrategy("(", ")", true), IDocument.DEFAULT_CONTENT_TYPE)
            acceptor.accept(new LFMultiLineTerminalsEditStrategy("[", "]", true), IDocument.DEFAULT_CONTENT_TYPE)
            acceptor.accept(new LFMultiLineTerminalsEditStrategy("{=", "=}", true), IDocument.DEFAULT_CONTENT_TYPE)
        }
        
        /**
         * Ensure that all text printed via println() is shown in the Console of the LF IDE.
         */
        def configureConsole() {
            if (!consoleInitialized) {
                val console = new MessageConsole("LF Output", null)
                ConsolePlugin.getDefault().getConsoleManager().addConsoles(newArrayList(console))
                ConsolePlugin.getDefault().getConsoleManager().showConsoleView(console)
                val stream = console.newMessageStream()

                System.setOut(new PrintStream(stream))
                System.setErr(new PrintStream(stream))

                consoleInitialized = true
            }
        }

        /** Specify these new acceptors. */
        override void configure(IEditStrategyAcceptor acceptor) {
            configureConsole()
            configureMultilineCodeBlock(acceptor)
            super.configure(acceptor)
            configureCodeBlock(acceptor)
        }
        
        static class LFMultiLineTerminalsEditStrategy extends MultiLineTerminalsEditStrategy {
            new(String leftTerminal, String rightTerminal, boolean nested) {
                super(leftTerminal, "", rightTerminal, nested)
            }

            override CommandInfo handleCursorInFirstLine(
                    IDocument document,
                    DocumentCommand command,
                    IRegion startTerminal,
                    IRegion stopTerminal) throws BadLocationException {
                // Create a modified command.
                val newC = new CommandInfo();
                // If this is handling delimiters { }, but the actual delimiters are {= =},
                // then do nothing.
                if (leftTerminal == "{") {
                    val start = document.get(startTerminal.offset, 2)
                    if (start == "{=") return newC
                }
                newC.isChange = true;
                newC.offset = command.offset;
                // Insert the Return character into the new command.
                newC.text += "\n"
                newC.text += command.text.trim;
                newC.cursorOffset = command.offset + newC.text.length();
                if (stopTerminal === null && atEndOfLineInput(document, command.offset)) {
                    newC.text += command.text + getRightTerminal();
                }
                if (stopTerminal !== null && stopTerminal.getOffset() >= command.offset) {
                    // If the right delimitter is on the same line as the left,
                    // collect the text between them and indent to the right place.
                    if (util.isSameLine(document, stopTerminal.getOffset(), command.offset)) {
                        // Get the string between the delimiters, trimed of whitespace
                        val string = document.get(
                            command.offset,
                            stopTerminal.getOffset() - command.offset
                        ).trim;
                        val indentation = document.indentationAt(command.offset)
                        // Indent by at least 4 spaces.
                        for (var i = 0; i < indentation / 4 + 1; i++) {
                            newC.text += "    "
                            newC.cursorOffset += 4
                        }
                        newC.text += string;
                        newC.text += command.text.trim;
                        newC.text += "\n"
                        for (var i = 0; i < indentation / 4; i++) {
                            newC.text += "    "
                        }
                        newC.length += string.length();
                    } else {
                        // Creating a new first line within a pre-existing block.
                        val indentation = document.indentationAt(command.offset)
                        var length = 0
                        for (var i = 0; i < indentation / 4 + 1; i++) {
                            newC.text += "    "
                            newC.cursorOffset += 4
                            length += 4
                        }
                        // The length field is, as usual for xtext, undocumented.
                        // It is not the length of the new command, but seems to be
                        // the number of characters of the original document that are
                        // to be replaced.
                        newC.length = 0
                    }
                }
                return newC;
            }
            
            // Expose base class protected methods within this package.
            override findStopTerminal(IDocument document, int offset) throws BadLocationException {
                super.findStopTerminal(document, offset)
            }
            override findStartTerminal(IDocument document, int offset) throws BadLocationException {
                super.findStartTerminal(document, offset)
            }
            override internalCustomizeDocumentCommand(IDocument document, DocumentCommand command) {
                super.internalCustomizeDocumentCommand(document, command)
            }
        }
        
        /**
         * Strategy for handling combinations of nested braces of different types.
         * This is based on CompoundMultiLineTerminalsEditStrategy by Sebastian Zarnekow,
         * but unfortunately, that class is not written in a way that can be overridden,
         * so this is a reimplementation.
         */
        static class CompoundLFMultiLineTerminalsEditStrategy extends AbstractTerminalsEditStrategy {

            /** Strategies used to handle combinations of nested braces. */
            List<LFMultiLineTerminalsEditStrategy> strategies = new LinkedList<LFMultiLineTerminalsEditStrategy>();

            new(String leftTerminal, String rightTerminal) {
                super(leftTerminal, rightTerminal)
                strategies.add(new LFMultiLineTerminalsEditStrategy("(", ")", true))
                strategies.add(new LFMultiLineTerminalsEditStrategy("{", "}", true))
                strategies.add(new LFMultiLineTerminalsEditStrategy("[", "]", true))
                strategies.add(new LFMultiLineTerminalsEditStrategy("{=", "=}", true))
            }

            override void internalCustomizeDocumentCommand(
                IDocument document,
                DocumentCommand command
            ) throws BadLocationException {
                if(command.length != 0) return;
                val lineDelimiters = document.getLegalLineDelimiters();
                val delimiterIndex = TextUtilities.startsWith(lineDelimiters, command.text);
                if (delimiterIndex != -1) {
                    var bestStrategy = null as LFMultiLineTerminalsEditStrategy;
                    var bestStart = null as IRegion;
                    for (LFMultiLineTerminalsEditStrategy strategy : strategies) {
                        var candidate = strategy.findStartTerminal(document, command.offset);
                        if (candidate !== null) {
                            if (bestStart === null || bestStart.getOffset() < candidate.getOffset()) {
                                bestStrategy = strategy;
                                bestStart = candidate;
                            }
                        }
                    }
                    if (bestStrategy !== null) {
                        bestStrategy.internalCustomizeDocumentCommand(document, command);
                    }
                }
            }
        }
    }
}
